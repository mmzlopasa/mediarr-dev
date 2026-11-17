# mediarr_api.model.ServerStats

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**photos** | **int** |  | 
**videos** | **int** |  | 
**usageBytes** | **int** | Total size of all originals | 
**users** | **int** |  | 
**processing** | **int** | Files still being prepared | 
**failed** | **int** | Files that could not be processed | 
**diskTotalBytes** | **int** |  | 
**diskFreeBytes** | **int** |  | 
**lastUploadAt** | [**DateTime**](DateTime.md) | When the newest file arrived; absent in an empty library | [optional] 
**version** | **String** |  | 
**jobs** | [**List<ServerStatsJobsInner>**](ServerStatsJobsInner.md) | One entry per queue of background work | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


