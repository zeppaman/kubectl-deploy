# kubectl-deploy
kubectl plugin for managin yml file with ease

## Why another kubernetes file mananger
Kubernetes is a perfect solution because it let you dominate infrastucture complexity by managin YAML files. Often, the YAML files became more complext than the infrastucute.
HELM is a good solution for managin packaged product or complex scenarios, but in some simpler use case (like deployng few pods) may be overkill. Kustomize is anothe built-in solution that's great but doesnt offert the templating opportunity that comes form HELM.
That's why I created a new tool designed for simplify life :)

## What it offers
1. Integrated in **kubectl**, yes you can invoke it by typing `kubectl deploy --all`
2. Template engine (you can define a base template for your app, then customize it)
3. Variable replacement
4. Versioned by design (throug git or helm)
5. Enviroment based configuration


## How it works
The base concept in kube deploy is the app. Each app is a yaml or folder that define a component of our architecture. I can contain all your resource or just ona part: you can arrange it as you prefer.

The deployment are divided into folder application or file application. The only difference is that 

Each application is:
- one file with yml extension (es. myapp.yml) into the root folder, or any file into the app folder (es. /myapp/myfile.yml)
- one file with suffic .values.yml in the same folder of the app file, or the file values.yaml inside the app folder. It contains parameters that will be used for templating and change the YAML values
- default values, in a file called values.yml located into the root folder

Each file can be suffixed by the enviroment name (prod, test, etc..) and this will be used for a specific deploy.

## Examples
Too cervellotic? Not at all. Let's see how it works.



### the plain file use case

Using the following file structure

```
 ~/myfolder
   + myapp.yml
   + myapp.values.yml
   + myapp.prod.yml
   + myapp.values.prod.yml
   + myapp.dev.yml
   + values.yml
```

Merge order:
- values: values.yml > app.values.yml > app.values.prod.yml
- template: app.yml > app.prod.yml

The two merged fiels are used for data binding.

This example define a standard couple of file (myapp.yml and myapp.values.yml) that make binding and produce a actualize yml file.
When you specify `prod` environment the myapp.prod.yml file that defines the base template is merged to the base myapp.yml so that you can add specific section to the yml definition for the prod environment. The myapp.values.prod.yaml is merged with myapp.value.yaml so that you can override some values for the prod env. Then the values are bindend with the template and a prod-specific file is produced.

Choosing the `dev` environment is quite the same, but it doesnt implement a specific version of the template (it is not mandatory, like it is not mandatory to have custom values for environemet.

The file values.yml is a base file and when presnet it is used as base for values file.

### the folder use case

```
 ~/myfolder
   + app
      + myfiele1.yml
      + myfile2.yml
      + myfile1.prod.yml
      + values.yml
      + values.prod.yml
      + myfiele1.yml
      + prod
         +myfile1.yaml
```

Merge order:
- values: values.yml > app/values.yml > app/prod/values.yml > app/values.prod.yml
- template: app/myfile1.yml > app/prod/myfile1.yml > app/myfile1.prod.yml (all the template file in app folder are merged into one, then transformed)

The two merged fiels are used for data binding.

All file in the folder root are compute (environment escalation) and merged. The the transformation is applied.

## Commands

`kubectl deploy -a appname` appname can be a folder or a yml file

`kubectl deploy --all` list all folder and yml file and deploy it (iteration of `kubectl deploy -a appname` over all apps)

`kubectl deploy --list` list all app in folder


options:
 - --dryrun
 - --debug
 - --autocommit



