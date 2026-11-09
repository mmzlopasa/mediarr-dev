# mediarr_api.model.Memory

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**kind** | **String** |  | 
**key** | **String** | Together with kind, what identifies this memory when hiding it. Not sent by older servers. | [optional] 
**year** | **int** | The year, for on_this_day | [optional] 
**title** | **String** | A date or date span. The client words the rest. | 
**titleParams** | [**MemoryTitleParams**](MemoryTitleParams.md) |  | [optional] 
**items** | [**List<TimelineItem>**](TimelineItem.md) |  | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


