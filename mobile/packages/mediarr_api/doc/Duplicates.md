# mediarr_api.model.Duplicates

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**total** | **int** | All groups, of which at most the first 100 are listed | 
**pending** | **int** | Photos not compared yet | 
**exactTotal** | **int** | Groups of the same file or picture | [optional] 
**resolving** | [**ResolveProgress**](ResolveProgress.md) |  | [optional] 
**groups** | [**List<DuplicateGroup>**](DuplicateGroup.md) |  | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


