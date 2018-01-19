DOCS BEING UPDATED

REQUIRED: 
INFLUXDB - time series database required for data storage
GRAFANA - graphing tool that links nicely into influx
CURL - needed to grab data from APIs
PYTHON - may be needed for some monitors
W3M - tool for grabbing data from claymore, working on removing this dependency

Structure:
/conf - your configuration file is here, it's somewhat documentented
/monitors - all the miner and pool monitors are here, easy to extend to others
/crontab - simple crontab examples for running the tool, can be run as local user without root
/dashboards - dashboard examples that may or may not work for you

Dashboard Examples:
![overview dashboard](dashboards/examples/overview_dash.JPG)


