# mediarr_api.model.ShareLink

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**token** | **String** | Returned only when the link is created | [optional] 
**label** | **String** |  | 
**hasPassword** | **bool** |  | 
**expiresAt** | [**DateTime**](DateTime.md) |  | [optional] 
**downloadLimit** | **int** |  | [optional] 
**downloadCount** | **int** |  | 
**allowDownload** | **bool** |  | 
**allowUpload** | **bool** |  | 
**uploadOnly** | **bool** |  | 
**showLocation** | **bool** |  | 
**watermark** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**hideFaces** | [**HideFaces**](HideFaces.md) |  | [optional] 
**visiblePeople** | **List<String>** | With hideFaces except: the people who stay visible | [optional] [default to const []]
**stripCamera** | **bool** |  | [optional] 
**stripDate** | **bool** |  | [optional] 
**askName** | **bool** |  | [optional] 
**visits** | **int** | Times it was opened in the last 90 days | [optional] 
**lastVisitAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


