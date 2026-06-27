# Servidor Web en Bash Avanzado

**CLUB ATLÉTICO PLATENSE CAMPEÓN 2025!!**

Servidor HTTP minimalista desarrollado completamente en Bash con fines educativos. Conmemorando el campeonato de futbol Argentino del 2025, en el cual fue Campeon el CLUB ATLETICO PLATENSE!!!

**Descripción**

Este proyecto implementa un servidor web funcional usando Bash + socat, diseñado para aprender cómo funciona HTTP desde cero.
Permite servir archivos estáticos (HTML, CSS, JS, imágenes, etc.) 

Ideal para entender el funcionamiento interno de un servidor web sin usar frameworks o lenguajes complejos.

**Características**

- Servidor HTTP en Bash
- Manejo de múltiples conexiones con socat
- Cache en RAM para archivos frecuentes
- Protección contra ataques comunes (path traversal, slowloris)
- Rate limiting por IP (anti spam)
- Logs de acceso (access.log)
- Soporte para archivos estáticos
- Preparado para HTTPS (usando Caddy como reverse proxy)
- Soporte para múltiples métodos HTTP (GET,POST,PUT,PATCH,DELETE)
- Soporta Multidominios

**Estructura**

- serverbash.sh     # Script principal
- index.html        # Página principal (Conmemorando al CLUB ATLETICO PLATENSE de Argentina, Campeon 2025)
- access.log        # Logs de conexiones
- tmp/              # Archivos temporales (auto-generados)
- dominio1/         # Archivos del Dominio1 (Soporte Multidominio)
- dominio2/         # Archivos del Dominio2 (Soporte Multidominio)

**Requisitos**

Instalar socat: sudo apt install socat (Sistemas basados en Debian)

**Uso**

Dar permisos de ejecución: chmod +x serverbash.sh

Ejecutar el servidor: ./serverbash.sh

Abrir en el navegador: http://localhost:8888 (default)

Probar metodos HTTP

- curl -X GET ip-del-sevidor:8888
- curl -X POST ip-del-sevidor:8888/platense.txt -d "Platense POST"
- curl -X PUT ip-del-sevidor:8888/platense.txt -d "Platense PUT"
- curl -X PATCH ip-del-sevidor:8888/platense.txt -d "Platense PATCH"
- curl -X DELETE ip-del-sevidor:8888/platense.txt

Probar Multidominios

- Editar el archivo /etc/hosts en linux, para poder resolver los dominios de prueba
  Ejemplo: Si mi ip es 192.168.0.14, configurar el archivo hosts de esta forma:
  sudo nano /etc/hosts
   - agregar:
      - 192.168.0.14  dominio1.com
      - 192.168.0.14  dominio2.com
- Despues de configurar el archivos hosts, navegar por los dominios
   - http://dominio1.com:8888
   - http://dominio2.com:8888  

**Uso con Docker**

También podés ejecutar el servidor usando Docker, sin necesidad de instalar dependencias manualmente.

Imagen disponible: docker pull christense/serverbash:1.0

Docker Compose

Podés levantar el servidor fácilmente con docker-compose:

services:
  serverbash:
    image: christense/serverbash:latest
    container_name: serverbash
    ports:
      - "9999:8888"
    volumes:
      - serverbash_data:/opt/ServidorCalamar
    restart: always

volumes:
  serverbash_data:

Ejecutar: docker-compose up -d

- Web: http://localhost:9999
- Web: http://dominio1.com:9999
- Web: http://dominio2.com:9999 

**Objetivo Educativo**

Este proyecto está hecho para:

- Entender cómo funcionan los servidores web
- Aprender protocolos y metodos HTTP
- Experimentar con Bash scripting avanzado
- Comprender sockets y concurrencia
