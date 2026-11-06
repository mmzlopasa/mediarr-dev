# mediarr_api.model.UserImport

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**source_** | **String** |  | 
**status** | **String** |  | 
**fromZip** | **bool** |  | 
**parts** | [**List<ImportPart>**](ImportPart.md) |  | [default to const []]
**total** | **int** | Files found, known once the import has read its ZIP files | 
**added** | **int** |  | 
**skipped** | **int** | Already there, or deleted at the source | 
**failed** | **int** |  | 
**lastError** | **String** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**finishedAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


