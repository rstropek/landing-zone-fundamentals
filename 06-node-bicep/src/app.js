// Add npm package for authentication (here: Managed Identity)
import { DefaultAzureCredential } from "@azure/identity";

// Add various clients for Azure
import { BillingManagementClient } from "@azure/arm-billing";
import { ResourceManagementClient } from "@azure/arm-resources";
import { ManagementGroupsAPI } from "@azure/arm-managementgroups";

// Import settings from .env file
import dotenv from "dotenv";
dotenv.config();

// === Enrollment account ===========================================================

// In a real application, the user would have to choose an enrollment account.
// An Azure Enrollment Account is the administrative and billing unit that 
// connects users and subscriptions to an Azure Enterprise Agreement.
// For demo purposes, this app prints all enrollment accounts on the screen.
// The output could e.g. fill a dropdown in a UI.
const client = new BillingManagementClient(new DefaultAzureCredential());

// Get first billing account (assumption: there is only one)
let billingAccountName;
for await (const account of client.billingAccounts.list()) {
    billingAccountName = account.name;
    break;
}

// Print list of enrollment accounts (id is important)
for await (const enrollmentAccount of client.enrollmentAccounts.listByBillingAccount(billingAccountName)) {
    console.log(enrollmentAccount.id, enrollmentAccount.properties.displayName);
}

// Let's assume the user choses enrollment account with id AZURE_ENROLLMENT_ACCOUNT_ID
const enrollmentAccountId = process.env.AZURE_ENROLLMENT_ACCOUNT_ID;

// === Management group =============================================================

// In a real application, the application logic would determine the management group
// under which the subscription should be created (e.g. based on the user's department).
// For demo purposes, this app prints all management groups on the screen.
// The output could e.g. fill a dropdown in a UI.
const managementGroupsClient = new ManagementGroupsAPI(new DefaultAzureCredential());
for await (const mg of managementGroupsClient.managementGroups.list()) {
    console.log(mg.name, mg.displayName);
}

// Let's assume the user choses management group with name rstropek-workshop
const managementGroupName = "rstropek-workshop";

// === Subscription ==================================================================

// Now we want to create a new subscription by executing a Bicep template (see
// folder `bicep`).

// We generate the technical name of the subscription randomly and
// set a display name. In a real application, the user would have to
// choose the display name of the subscription.
import crypto from 'crypto';
const newSubscriptionName = crypto.randomUUID();
const newSubscriptionDisplayName = 'Rainers auto creation test';

// Note: The ResourceManagementClient needs a subscription ID. However,
// this application only deploys resources on a tenant level. Strictly speaking,
// the subscription ID is not needed for this operation. Still, the SDK
// requires it. So we provide any valid subscription ID.
const subscriptionId = "96ff2809-c950-4a50-9eb6-f26f23d32735";
const resourceClient = new ResourceManagementClient(new DefaultAzureCredential(), subscriptionId);

// Read the ARM template (is has been built from the bicep files using
// `az bicep build --file main.bicep`).
import fs from 'fs';
import path from 'path';
const templatePath = path.join(process.cwd(), 'bicep', 'main.json');
const template = JSON.parse(fs.readFileSync(templatePath, 'utf8'));

// Generate a deployment name based on the current date and time.
const deploymentName = `deployment-${new Date().toISOString().replaceAll(':', '-')}`;

// Deploy the template = create the subscription and assign it to the management group
const result = await resourceClient.deployments.beginCreateOrUpdateAtTenantScope(
    deploymentName,
    {
        location: "westeurope",
        properties: {
            mode: "Incremental",
            template,
            parameters: {
                billingScope: { value: enrollmentAccountId },
                subscriptionName: { value: newSubscriptionName },
                subscriptionDisplayName: { value: newSubscriptionDisplayName },
                managementGroupId: { value: managementGroupName }
            }
        }
    }
);

try {
    console.log("waiting for deployment to complete");
    const deployment = await result.pollUntilDone();
    console.log(deployment);
    console.log("deployment completed");
} catch (error) {
    console.log("deployment failed");
}

// In case of an error, we can print the deployment operations to get more details
// for await (const op of resourceClient.deploymentOperations.listAtTenantScope(deploymentName)) {
//     console.log(op);
// }
