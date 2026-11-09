# mediarr_api.model.LibraryExport

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**userId** | **String** |  | 
**userEmail** | **String** |  | 
**status** | **String** | removed: the parts were removed a week after the export was done | 
**startedByAdmin** | **bool** | Started by an administrator, not by the owner | 
**startedBy** | **String** | The name of who started it | 
**totalFiles** | **int** |  | 
**totalBytes** | **int** |  | 
**doneFiles** | **int** |  | 
**doneBytes** | **int** |  | 
**missing** | **int** | Files in the database that were not on the disk | 
**lastError** | **String** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**finishedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**expiresAt** | [**DateTime**](DateTime.md) | When the parts are removed | [optional] 
**parts** | [**List<LibraryExportPart>**](LibraryExportPart.md) |  | [default to const []]
**canDownload** | **bool** | Whether the one asking may download the parts | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


