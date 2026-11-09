# mediarr_api.model.ShareLinkCreate

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**label** | **String** |  | [optional] 
**password** | **String** |  | [optional] 
**expiresAt** | [**DateTime**](DateTime.md) |  | [optional] 
**downloadLimit** | **int** |  | [optional] 
**allowDownload** | **bool** |  | [optional] [default to true]
**allowUpload** | **bool** |  | [optional] [default to false]
**uploadOnly** | **bool** |  | [optional] [default to false]
**showLocation** | **bool** |  | [optional] [default to false]
**watermark** | **String** |  | [optional] 
**hideFaces** | [**HideFaces**](HideFaces.md) |  | [optional] 
**visiblePeople** | **List<String>** |  | [optional] [default to const []]
**stripCamera** | **bool** |  | [optional] [default to true]
**stripDate** | **bool** |  | [optional] [default to false]
**askName** | **bool** |  | [optional] [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


