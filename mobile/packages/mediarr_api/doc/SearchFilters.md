# mediarr_api.model.SearchFilters

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**from** | [**DateTime**](DateTime.md) |  | [optional] 
**to** | [**DateTime**](DateTime.md) |  | [optional] 
**person** | **String** | The name of a person found in the words | [optional] 
**people** | [**List<PersonRef>**](PersonRef.md) |  | [optional] [default to const []]
**peopleMatch** | **String** |  | [optional] 
**place** | **String** |  | [optional] 
**camera** | **String** |  | [optional] 
**lens** | **String** |  | [optional] 
**type** | **String** |  | [optional] 
**minRating** | **int** |  | [optional] 
**pick** | **int** | 1 picked, -1 rejected, 0 unmarked | [optional] 
**tags** | **List<String>** |  | [optional] [default to const []]
**album** | [**AlbumRef**](AlbumRef.md) |  | [optional] 
**notInAlbum** | **bool** |  | [optional] 
**favorite** | **bool** |  | [optional] 
**words** | **String** | What is left of the query after the filters were taken out | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


