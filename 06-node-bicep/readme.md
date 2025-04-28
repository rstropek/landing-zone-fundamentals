## List Billing Enrollments

```sh
az billing enrollment-account list
```

## Assign Permissions

```sh
az role assignment create --scope '/' --role 'Owner' --assignee-object-id $(az ad signed-in-user show --query id --output tsv) --assignee-principal-type User
```

For details see [https://github.com/Azure/Enterprise-Scale/wiki/ALZ-Setup-azure](https://github.com/Azure/Enterprise-Scale/wiki/ALZ-Setup-azure).

## Compile Subscription Bicep

```sh
az bicep build --file subscriptions.bicep 
```
