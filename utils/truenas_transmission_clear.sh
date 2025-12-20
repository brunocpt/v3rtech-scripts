#!/bin/bash

SERVER="192.168.0.12"
PORT="9091"
URL="http://$SERVER:$PORT/transmission/rpc"

# Verifica dependência
if ! command -v jq >/dev/null 2>&1; then
  echo "Erro: o utilitário 'jq' é necessário, mas não está instalado."
  exit 1
fi

echo "Obtendo session-id do Transmission..."

# Extrai apenas o primeiro X-Transmission-Session-Id dos cabeçalhos
SESSION_ID=$(curl -s -D - -o /dev/null "$URL" \
  -H "Content-Type: application/json" \
  -d '{}' | awk '/X-Transmission-Session-Id/ {print $2}' | tr -d '\r' | head -n 1)

if [ -z "$SESSION_ID" ]; then
  echo "Erro ao obter o Session ID do Transmission. Verifique conexão e daemon."
  exit 1
fi

echo "Session ID obtido com sucesso: $SESSION_ID"
echo "Consultando torrents..."

RESPONSE=$(curl -s -X POST "$URL" \
  -H "X-Transmission-Session-Id: $SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{
        "method": "torrent-get",
        "arguments": {
          "fields": ["id", "name", "percentDone", "status"]
        }
      }')

if ! echo "$RESPONSE" | jq . >/dev/null 2>&1; then
  echo "Erro: resposta do Transmission não é JSON válido:"
  echo "$RESPONSE"
  exit 1
fi

echo "$RESPONSE" | jq -c '.arguments.torrents[]' | while read -r torrent; do
  ID=$(echo "$torrent" | jq '.id')
  NAME=$(echo "$torrent" | jq -r '.name')
  PERCENT=$(echo "$torrent" | jq '.percentDone')
  STATUS=$(echo "$torrent" | jq '.status')

  # STATUS 0 = Stopped, 6 = Seeding
  if (( $(echo "$PERCENT >= 0.9999" | bc -l) )) && [[ "$STATUS" == "0" || "$STATUS" == "6" ]]; then
    echo "✔ Torrent #$ID - $NAME está completo. Removendo..."
    curl -s -X POST "$URL" \
      -H "X-Transmission-Session-Id: $SESSION_ID" \
      -H "Content-Type: application/json" \
      -d "{
            \"method\": \"torrent-remove\",
            \"arguments\": { \"ids\": [$ID], \"delete-local-data\": false }
          }" > /dev/null
  else
    echo "⏩ Torrent #$ID - $NAME ainda não está pronto (status: $STATUS, %: $PERCENT). Ignorado."
  fi
done

echo "✅ Limpeza concluída."

