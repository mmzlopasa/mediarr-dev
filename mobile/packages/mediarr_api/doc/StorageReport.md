# mediarr_api.model.StorageReport

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**template** | **String** |  | 
**dryRun** | **bool** |  | 
**running** | **bool** |  | 
**startedAt** | [**DateTime**](DateTime.md) |  | 
**finishedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**checked** | **int** |  | 
**moved** | **int** | Moved, or with dryRun would move | 
**failed** | **int** |  | 
**samples** | [**List<StorageMove>**](StorageMove.md) |  | [default to const []]
**errors** | **List<String>** |  | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


