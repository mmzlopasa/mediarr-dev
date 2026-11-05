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

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


