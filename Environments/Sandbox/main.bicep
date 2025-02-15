// Copyright (c) Microsoft Corporation. 
// Licensed under the MIT License.
@description('Name of the Budget. It should be unique within a resource group.')
param budgetName string = '${resourceGroup().name}-budget'

@description('The total amount of cost or usage to track with the budget')
param amount int = 1000

@description('The time covered by a budget. Tracking of the amount will be reset based on the time grain.')
@allowed([
  'Monthly'
  'Quarterly'
  'Annually'
])
param timeGrain string = 'Monthly'

@description('The start date must be first of the month in YYYY-MM-DD format. Future start date should not be more than three months. Past start date should be selected within the timegrain preiod.')
param startDate string = '${substring(utcNow('yyyy-MM-dd'), 0,7)}-01'


@description('The end date for the budget in YYYY-MM-DD format. If not provided, we default this to 10 years from the start date.')
param endDate string = ''

@description('Threshold value associated with a notification. Notification is sent when the cost exceeded the threshold. It is always percent and has to be between 0.01 and 1000.')
param firstThreshold int = 90

@description('Threshold value associated with a notification. Notification is sent when the cost exceeded the threshold. It is always percent and has to be between 0.01 and 1000.')
param secondThreshold int = 110

@description('The list of email addresses to send the budget notification to when the threshold is exceeded.')
param contactEmails array 

param newTags object = {
  budget: 'true'
  stopstart: 'true'
}


//add tags stop/start tag to resourceGroupTags without overwriting
resource resourceGroupTagsUpdate 'Microsoft.Resources/tags@2021-04-01' = {
  name: 'default'
  properties: {
    tags: union(newTags, resourceGroup().tags)
  }
}

//Policy Documentation is here: https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/policyassignments?pivots=deployment-language-bicep

//Valid Locations
resource assignmentLocations 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
    name: 'Allowed Locations'
    properties: {
        displayName: 'Allowed Locations'
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
        enforcementMode: 'Default'
        parameters:{
            listOfAllowedLocations: {
                value: [
                    'uksouth'
                    'ukwest'
                    'westeurope'
                    'northeurope'
                ]
            } 
        }
    }
}

// Network interfaces should not have public IPs
resource assignmentNoPublic 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'Network interfaces should not have public IPs'
  properties: {
      displayName: 'Network interfaces should not have public IPs'
      policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114'
      enforcementMode: 'Default'
  }
}

// App Service not public access
resource assignmentNoPublicAppService 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'App Service apps should disable public network access'
  properties: {
      displayName: 'App Service apps should disable public network access'
      policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/1b5ef780-c53c-4a64-87f3-bb9c8c8094ba'
      enforcementMode: 'Default'
      parameters:{
        effect: {
            value: 'Deny'
        } 
    }
  }
}


resource budget 'Microsoft.Consumption/budgets@2021-10-01' = {
  name: budgetName
  properties: {
    timePeriod: {
      startDate: startDate
      endDate: endDate
    }
    timeGrain: timeGrain
    amount: amount
    category: 'Cost'
    notifications: {
      NotificationForExceededBudget1: {
        enabled: true
        operator: 'GreaterThan'
        threshold: firstThreshold
        contactEmails: contactEmails
      }
      NotificationForExceededBudget2: {
        enabled: true
        operator: 'GreaterThan'
        threshold: secondThreshold
        contactEmails: contactEmails
      }
    }
  }
}

