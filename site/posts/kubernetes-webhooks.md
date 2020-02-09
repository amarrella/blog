---
title: "Kubernetes Webhooks in Haskell and Dhall"
author: Alessandro Marrella
date: 2020-02-09
tags: [haskell, dhall]
description: How to write a kubernetes admission controller in Haskell
---

I spent the past few weeks fighting with Kubernetes [Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) (also known as Mutating/Validating Webhooks). 

Admission controllers are a quite powerful tool, that allow intercepting requests to the Kubernetes API Server before an object is persisted, and perform custom validations or mutations on it. 

There are two main components to an admission controller:
1. A *webhook* exposed over HTTPS which accepts an `AdmissionReviewRequest` and returns an `AdmissionReviewResponse`
2. A *configuration* entry of type `MutatingWebhookConfiguration` or `ValidatingWebhookConfiguration`

In this post, I will present the [kubernetes-webhook-haskell](https://hackage.haskell.org/package/kubernetes-webhook-haskell) library, which is used to create the webhook, and a `dhall` template that helps with the configuration and tls certificates. Many tutorials I found online show how to do this with a bash script, here we take a more declarative approach using [cert-manager](https://cert-manager.io). 

## How to write a Kubernetes Webhook in Haskell
This is a step by step explanation on how to write a webhook in Haskell. If you are familiar with Haskell, and servant, you can skip this section and [look at the example](https://github.com/EarnestResearch/kubernetes-webhook-haskell#kubernetes-webhook-haskell) instead.

First of all, *set up a project* using your favorite build tool, adding `kubernetes-webhook-haskell` as a dependency.

Second, you need to *create an endpoint* where you will be receiving the requests. In `servant`, this looks like:
```haskell
type API =
  -- /mutate
  "mutate" :> ReqBody '[JSON] AdmissionReviewRequest :> Post '[JSON] AdmissionReviewResponse
```

Third, you need to *set up the server so that it runs on https* (kubernetes only allows https for webhooks), with `warp-tls` you can do something like:

```haskell
main :: IO ()
main = do
  let tlsOpts = tlsSettings "/certs/tls.crt" "/certs/tls.key"
      warpOpts = setPort 8080 defaultSettings
  runTLS tlsOpts warpOpts app
```
If you will be using the template provided in the section below, we will load the certificates there.

Fourth, you can *write the webhook logic*. Depending on whether you are writing a validating or a mutating webhook, the library exposes two different functions: `mutatingWebhook` and `validatingWebhook`. The logic is similar for both, you parse a request, write a handler for it returning either an error (of type `Status`) or a `Allowed`/`Patch` (see http://jsonpatch.com/ for information on how to write the patch).

For example, if you want to write a mutating webhook that adds a toleration to your pods, you should define the Toleration type:
```haskell
data Toleration
  = Toleration
      { effect :: Maybe TolerationEffect,
        key :: Maybe Text,
        operator :: Maybe TolerationOperator,
        tolerationSeconds :: Maybe Integer,
        value :: Maybe Text
      }
  deriving (Generic, A.ToJSON)

data TolerationEffect = NoSchedule | PreferNoSchedule | NoExecute deriving (Generic, A.ToJSON)

data TolerationOperator = Exists | Equal deriving (Generic, A.ToJSON)
```

and then your patch can look like:
```haskell
patch :: W.Patch
patch =
  W.Patch
    [ 
        W.PatchOperation
        { op = W.Add,
          path = "/spec/tolerations/-",
          from = Nothing,
          value = Just $ A.toJSON toleration
        }
    ]
  where 
    toleration = 
      Toleration
        { effect = Just NoSchedule,
          key = Just "foo",
          operator = Just Equal,
          tolerationSeconds = Nothing,
          value = Nothing
        }
```

Then your patch in the `mutatingWebhook`:
```haskell
mutate :: AdmissionReviewRequest -> AdmissionReviewResponse
mutate = mutatingWebhook req (\_ -> Right patch)
```

And that's it! Compile and create a docker image, and jump to the next section.

## How to deploy the Kubernetes Webhook using Dhall
Regardless of the fact that you created the webhook with the library above or not, this part explains how to deploy a webhook to Kubernetes by using an opinionated Dhall template.

Dhall is a configuration language aimed at writing maintainable configuration files. It's a great language to write infrastructure configuration in, with features such as: 
- (safe) imports
- functions
- types
- 
See [dhall-lang.org](https://dhall-lang.org) for more information about the language.

As a *pre-requisite* for this part, you need to:
- Install [cert-manager](https://cert-manager.io) in your cluster. This has been tested with cert-manager `v0.13.0` with the ca-injector enabled.
- Install [dhall-to-yaml](https://dhall-lang.org) on your laptop or in your continuous deployment / gitops. This has been tested with dhall-to-yaml `v1.6.1`.

Then, *add a custom label* to the namespaces you want to apply the webhook to:
```sh
kubectl label namespace my-namespace my-webhook=enabled
```

Deploying a webhook now is as easy as replacing the values in this example with yours:
```haskell
-- webhook.dhall
let k8s = 
    https://raw.githubusercontent.com/dhall-lang/dhall-kubernetes/6a47bd50c4d3984a13570ea62382a3ad4a9919a4/1.14/package.dhall

let Webhook = 
    https://raw.githubusercontent.com/EarnestResearch/dhall-packages/v0.11.1/kubernetes/webhook/package.dhall

let config =
      Webhook::{
      , imageName = "docker/whalesay" -- replace with your webhook docker image
      , name = "my-mutating-webhook" -- replace with a meaningful name
      , namespace = "default" -- replace with the namespace where you want to deploy it
      , path = "/mutate" -- replace with the path where the webhook is exposed
      , port = 8080 --replace with the port where the webhook is exposed
      , rules = -- replace with the rules you care about
        [ k8s.RuleWithOperations::{
          , operations = [ "CREATE", "UPDATE" ]
          , apiGroups = [ "" ]
          , apiVersions = [ "v1" ]
          , resources = [ "pods" ]
          }
        ]
      , namespaceSelector = Some k8s.LabelSelector::{
        , matchLabels = toMap { my-webhook = "enabled" } -- replace with the label you used for the namespace
        }
      }

in  Webhook.renderMutatingWebhook config -- or Webhook.renderValidatingWebhook 
```

Once the file is ready, run 
```
echo ./webhook.dhall | dhall-to-yaml --omit-empty | kubectl apply -n default -f -
```

The webhook will be installed and ready to use, with all the certificates loaded.
