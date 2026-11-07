# mediarr_api.model.TimelineItem

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**kind** | **String** |  | 
**ratio** | **double** | Width divided by height, as displayed | 
**blurhash** | **String** |  | [optional] 
**isFavorite** | **bool** |  | 
**isLive** | **bool** |  | [optional] 
**isPanorama** | **bool** | A 360° panorama | [optional] 
**stackSize** | **int** | Shots in this stack, when it is one. Only the main shot shows on the timeline | [optional] 
**isShared** | **bool** | Belongs to someone else, shared with this user | [optional] 
**durationMs** | **int** |  | [optional] 
**localAt** | **String** | Local capture time without a zone: 2006-01-02T15:04:05 | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


