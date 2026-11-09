# mediarr_api.model.QRSignIn

## Load the model package
```dart
import 'package:mediarr_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**code** | **String** | Eight characters, shown as XXXX-XXXX for typing by hand | 
**link** | **String** | mediarr://sign-in?server=...&code=..., the contents of the QR code | 
**server** | **String** | The address the code was made on | [optional] 
**expiresAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


