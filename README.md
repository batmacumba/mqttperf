# mqttperf
## Dependências
- paho-mqtt
- descriptive_statistics
## Uso

```console
Usage: ruby mqttperf.rb [arguments]

--mode: escrita 'w', leitura 'r' ou spread 's'
--clients: número de clientes
--length: comprimento das mensagens enviadas
--address: endereço IP do servidor MQTT
--cert: path do certificado SSL
--key: path da chave privada
--port: porta do servidor, caso essa seja diferente da padrão
```

Caso **cert** e **key** sejam passados como argumentos válidos, o programa tentará se conectar à porta 8883 to servidor usando SSL/TLS.
