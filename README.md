# Personal Weather Station (PWS)
This function app allows you to get the data **directly** from your own PWS (personal weather station) and publish this to MQTT. So this does **NOT** require that you register your PWS to cloud accounts, like WeatherUnderground, Ecowitt, WeatherCloud, WOW (takes weeks to get key), etc, or the use of WeeWX (extra software).

**This configuration will directly capture the data from your weather station!** 

## Thanks to Xorfor!
Special thanks to Xorfor who has created the [HA-PWS](https://github.com/Xorfor/HA-PWS) (and previously the Domoticz-PWS-Plugin) project initially. This project is inspirated by him and is using his calculations.

Do you like his work? Give him some [support](#support)

# Docker container
This function app, which can be ran in a docker container, will receive the data and publish this to MQTT.
Look at the [docker-comopose.yml](docker-compose.yml) for the docker setup.
You need to download the 'Function Apps' folder to /home/{USER}/Function Apps
Download and update the [.env.azfunc](.env.azfunc) file for the environment variables (like MQTT server, username, password, etc)

# Prerequisites
1. Your PWS needs to be connected to your network. This can be done by using [WS View](#ws-view-plus-ws-view-or-ws-tool) app.
1. You need an Mosquitto server. You can also create a docker container via: [MQTT (Mosquitto)](https://hub.docker.com/_/eclipse-mosquitto)

## Supported devices
In general, if the station is supplied with `EasyWeather` software (version 1.4.x, 1.5.x, 1.6.x), it is likely that the station will work with this HA Configuration!

### WS View Plus (WS View or WS Tool)
If supported by your PWS, connect your PWS with `WS View Plus` (and also the 'older' `WS View` or `WS Tool`) to your router by wifi, so that your PWS can upload weather data.

1. Install `WS View Plus` on your mobile device
    * [Google Play Store](https://play.google.com/store/apps/details?id=com.ost.wsautool)
    * [Apple App Store](https://apps.apple.com/nl/app/wsview-plus/id1581353359)
1. , or `WS View`
    * [Google Play Store](https://play.google.com/store/apps/details?id=com.ost.wsview)
    * [Apple App Store](https://apps.apple.com/us/app/ws-view/id1362944193)
1. , or `WS Tool`
    * [Google Play Store](https://play.google.com/store/apps/details?id=com.dtston.wstool)
    * [Apple App Store](https://apps.apple.com/nl/app/ws-tool/id1125344077)
1. Follow the instructions to connect your PWS to your router
1. Goto to Device List in Menu and choose your PWS
1. Click on Next until you are on on the `Customized` page
1. Choose `Enable`
1. For `Protocol Type Same As` choose `Ecowitt`
    * With Ecowitt the data will be send with a POST. Wunderground is using a GET, which is not supported by this solution.
1. For `Server IP / Hostname` enter your docker-server ip address, eg. 192.168.0.10
2. For `Path` enter: `/api/PWS2mqtt`
3. `Port` enter a port number `80`
4. `Upload Interval`, leave it `60` seconds
5. Click on `Save`

<img src="images/WS_View_setup.png" width=400>

## Home Assistant configuration
Use the [configuration.yaml](configuration.yaml) to setup the PWS entities.

Use the [customize.yaml](customize.yaml) to get appropriate icons for the entities

## Sensors
| ID                               | Type  |             UoM | Description
| :---                             | :---  |            ---: | :--- 
| `sensor.pws_temperature`         | Float |              °C | Outdoor temperature
| `sensor.pws_temperature_indoor`  | Float |              °C | Indoor temperature
| `sensor.pws_humidity`            | Int   |               % | Outdoor humidity
| `sensor.pws_humidity_indoor`     | Int   |               % | Indoor humidity
| `sensor.pws_barometer_relative`  | Float |             hPa | Pressure (relative)
| `sensor.pws_barometer_absolute`  | Float |             hPa | Pressure (absolute)
| `sensor.pws_rainrate`            | Float |            mm/h | Current rain rate
| `sensor.pws_rain`                | Float |              mm | Rain daily total
| `sensor.pws_solar_radiation`     | Float | W/m<sup>2</sup> | Solar radiation 
| `sensor.pws_uv`                  | Int   |        UV Index | UV Index
| `sensor.pws_wind_speed`          | Float |             m/s | Wind speed
| `sensor.pws_wind_gust`           | Float |             m/s | Wind gust
| `sensor.pws_wind_direction`      | Int   |               ° | Wind direction
| `sensor.pws_wind_direction_text` | Text  |                 | Wind direction in text, like 'NNE', 'N', 'SSW', 'SW', etc. (calculated, based on `sensor.pws_wind_direction`)
| `sensor.pws_stationtype`         | Text  |                 | Firmware name/version, eg. `EasyWeatherV1.6.4`
| `sensor.pws_model`               | Text  |                 | Weatherstation model, eg. `WS2900`
| `sensor.pws_dewpoint`            | Float |              °C | Dew point (calculated, because it is not supported in the Ecowitt protocol)
| `sensor.pws_windchill`           | Float |              °C | Windchill (calculated, because it is not supported in the Ecowitt protocol)
| `sensor.pws_heat_index`          | Float |              °C | Heat index (calculated, based on `sensor.pws_temperature` and `sensor.pws_humidity`)
| `sensor.pws_platform`            | Text  |                 | HA platform in this configuration, eg. `webhook` (for debugging)
| `sensor.pws_webhook_id`          | Text  |                 | HA name for this webhook in the configuration, `pws` (for debugging)

## Screenshots
![Screenshot](images/entities.jpg)
![Screenshot](images/overview.jpg)

## Data
Example of data received from the PWS:

```
Data: {
  "PASSKEY": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", 
  "baromabsin": "30.039",
  "baromrelin": "30.068",
  "dailyrainin": "0.921", 
  "dateutc": "2022-09-17 21:19:41", 
  "eventrainin": "1.461", 
  "hourlyrainin": "0.031", 
  "humidity": "95", 
  "humidityin": "59", 
  "maxdailygust": "19.5", 
  "model": "WS2900", 
  "monthlyrainin": "3.461", 
  "rainratein": "0.000", 
  "solarradiation": "0.00", 
  "stationtype": "EasyWeatherV1.6.4", 
  "tempf": "52.9", 
  "tempinf": "68.2", 
  "totalrainin": "131.039", 
  "uv": "0", 
  "weeklyrainin": "1.472", 
  "winddir": "173", 
  "windgustmph": "1.1", 
  "windspeedmph": "0.9", 
  "yearlyrainin": "131.039"
  }
```

## Possibilities
[Display rain per day](https://github.com/Xorfor/HA-PWS/blob/main/Rain_per_day.md)

[Display rainrate over a week](https://github.com/Xorfor/HA-PWS/blob/main/Rainrate.md)

## Support
[By Xorfor (who created the HA-PWS project) a 🍺](https://www.buymeacoffee.com/xorfor)