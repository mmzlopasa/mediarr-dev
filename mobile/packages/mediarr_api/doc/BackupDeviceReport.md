# mediarr_api.model.BackupDeviceReport

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** |  | 
**platform** | **String** |  | 
**appVersion** | **String** |  | 
**pending** | **int** |  | 
**working** | **int** |  | 
**verified** | **int** |  | 
**failed** | **int** |  | 
**failures** | [**List<BackupDeviceFailure>**](BackupDeviceFailure.md) | Left out, the ones from before stay | [optional] [default to const []]
**checksums** | **List<String>** | Hex SHA-256 of files confirmed on the server, at most 5000 at a time | [optional] [default to const []]
**replace** | **bool** | These checksums start the list anew; the following reports add to it | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


