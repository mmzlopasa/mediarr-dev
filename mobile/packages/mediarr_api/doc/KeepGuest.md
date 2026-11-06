# mediarr_api.model.KeepGuest

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**name** | **String** |  | 
**status** | **String** |  | 
**quotaBytes** | **int** |  | 
**usedBytes** | **int** | Everything kept, what it deleted included | 
**deletedBytes** | **int** | What it deleted, kept for 90 days | 
**address** | **String** | The address of this server the guest was told | 
**inviteExpiresAt** | [**DateTime**](DateTime.md) |  | [optional] 
**lastBackupAt** | [**DateTime**](DateTime.md) |  | [optional] 
**lastSeenAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


