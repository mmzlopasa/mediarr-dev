# mediarr_api.model.DateFix

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ids** | **List<String>** |  | [default to const []]
**action** | **String** |  | 
**minutes** | **int** | shift: how far, forward or back | [optional] 
**takenAt** | **String** | set: RFC 3339 with the offset of where they were taken | [optional] 
**cameraZone** | **String** | travel: the zone the camera's clock was on, such as Europe/Zagreb | [optional] 
**placeZone** | **String** | travel: the zone where they were taken, such as Asia/Tokyo | [optional] 
**dryRun** | **bool** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


