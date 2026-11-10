# mediarr_api.model.ServerSettings

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**trashDays** | **int** |  | 
**imageQuality** | **int** |  | 
**previewSize** | **int** |  | 
**videoQuality** | **int** | Lower is better and larger | 
**videoMaxHeight** | **int** |  | 
**loginMessage** | **String** |  | 
**passwordLogin** | **bool** |  | 
**maintenance** | **bool** | Only administrators can use the server | 
**faceMinScore** | **double** | How sure a face must be | 
**faceMaxDistance** | **double** | How alike two faces must be to be one person | 
**workerConcurrency** | **int** | 0 uses WORKER_CONCURRENCY. Applies after a restart of the worker | 
**videoWorkers** | **int** | Applies after a restart of the worker | 
**analysisWorkers** | **int** | Applies after a restart of the worker | 
**externalScanHours** | **int** |  | 
**visibleOnNetwork** | **bool** | Apps on the same network can find this server. Left out keeps it on | [optional] 
**serverName** | **String** | What people see this server called. Left out keeps the name it has | [optional] 
**dlnaServer** | **bool** | TVs on the home network see the albums of dlnaOwner, without a password. Turning it on makes the administrator who does it the owner. Left out keeps it as it is | [optional] 
**dlnaOwner** | **String** | Whose albums TVs see, while dlnaServer is on | [optional] [readonly] 
**dlnaAnnounced** | **bool** | The dlna service has asked for the description in the last few minutes, so TVs can find the server | [optional] [readonly] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


