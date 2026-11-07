# mediarr_api.model.BackupDevice

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**name** | **String** |  | 
**platform** | **String** |  | 
**appVersion** | **String** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**reportedAt** | [**DateTime**](DateTime.md) |  | 
**quiet** | **bool** | Has not reported for longer than its owner allows | 
**pending** | **int** | Waiting on the phone, as the phone counts | 
**working** | **int** |  | 
**verified** | **int** | Confirmed, as the phone counts | 
**failed** | **int** |  | 
**files** | **int** | Checksums the phone has given the server | 
**confirmed** | **int** | Of those, safe on the server, as the server counts | 
**trashed** | **int** | Of those, in the trash | 
**gone** | **int** | Of those, no longer on the server | 
**ownerEmail** | **String** |  | 
**ownerName** | **String** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


