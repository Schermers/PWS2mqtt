# PWS
This function app allows you to get the data **directly** from your own PWS (personal weather station) and publish this to MQTT. So this does **NOT** require that you register your PWS to cloud accounts, like WeatherUnderground, Ecowitt, WeatherCloud, WOW (takes weeks to get key), etc, or the use of WeeWX (extra software).

## Thanks to Xorfor!
Special thanks to Xorfor who has created the [HA-PWS](https://github.com/Xorfor/HA-PWS) (and previously the Domoticz-PWS-Plugin) project initially. This project is inspirated by him and is using his calculations.

Do you like his work? Give him some [support](#support)

# Docker container
This function app, which can be ran in a docker container, will receive the data and publish this to MQTT.
Look at the [docker-comopose.yml](docker-compose.yml) for the docker setup.
You need to download the 'Function Apps' folder to /home/{USER}/Function Apps
Download and update the [.env.azfunc](.env.azfunc) file for the environment variables (like MQTT server, username, password, etc)

# Prerequisites
- [MQTT (Mosquitto)](https://hub.docker.com/_/eclipse-mosquitto)

**This configuration will directly capture the data from your weather station!** 

## Support
[By Xorfor (who created the HA-PWS project) a 🍺](https://www.buymeacoffee.com/xorfor)