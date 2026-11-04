# mediarr_api.model.AssetDetail

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**isOwner** | **bool** | Only the owner can change or delete the asset | [optional] 
**downloadAllowed** | **bool** | False on a public link that does not allow downloads | [optional] 
**edits** | [**AssetEdits**](AssetEdits.md) |  | [optional] 
**isEditing** | **bool** | New previews are being made after an edit | [optional] 
**description** | **String** | From the local model. Only for the owner | [optional] 
**isMissing** | **bool** | The file of an external library was not found on the last scan | [optional] 
**tags** | **List<String>** | Only for the owner | [optional] [default to const []]
**stack** | **List<String>** | All shots of its stack, the main one first. Only for the owner | [optional] [default to const []]
**people** | [**List<PersonRef>**](PersonRef.md) | Only for the owner | [optional] [default to const []]
**city** | **String** |  | [optional] 
**state** | **String** |  | [optional] 
**country** | **String** |  | [optional] 
**id** | **String** |  | 
**originalName** | **String** |  | 
**kind** | **String** |  | 
**status** | **String** |  | 
**mimeType** | **String** |  | [optional] 
**sizeBytes** | **int** |  | 
**width** | **int** |  | [optional] 
**height** | **int** |  | [optional] 
**isFavorite** | **bool** |  | 
**isArchived** | **bool** |  | 
**localAt** | **String** |  | 
**offsetMinutes** | **int** |  | [optional] 
**hasCaptureTime** | **bool** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**newerId** | **String** |  | [optional] 
**olderId** | **String** |  | [optional] 
**durationMs** | **int** |  | [optional] 
**videoCodec** | **String** |  | [optional] 
**hlsReady** | **bool** | The adaptive stream at video/master.m3u8 can be played | [optional] 
**liveVideoId** | **String** | The video of a Live Photo | [optional] 
**hasMotion** | **bool** | An Android Motion Photo, with its video at /motion | [optional] 
**sprite** | [**Sprite**](Sprite.md) |  | [optional] 
**camera** | **String** |  | [optional] 
**lens** | **String** |  | [optional] 
**iso** | **int** |  | [optional] 
**fNumber** | **double** |  | [optional] 
**exposureTime** | **String** |  | [optional] 
**focalLength** | **double** |  | [optional] 
**latitude** | **double** |  | [optional] 
**longitude** | **double** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


