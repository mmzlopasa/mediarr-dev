# mediarr_api.model.Album

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**title** | **String** |  | 
**description** | **String** |  | 
**role** | **String** |  | 
**ownerId** | **String** |  | 
**ownerName** | **String** |  | 
**assetCount** | **int** |  | 
**coverAssetId** | **String** |  | [optional] 
**order** | **String** |  | 
**isSmart** | **bool** |  | 
**rules** | [**AlbumRules**](AlbumRules.md) |  | [optional] 
**members** | [**List<AlbumMember>**](AlbumMember.md) |  | [optional] [default to const []]
**parentId** | **String** | The album this one is in, when this user can see that one | [optional] 
**childCount** | **int** | Albums in this one that this user can see | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


