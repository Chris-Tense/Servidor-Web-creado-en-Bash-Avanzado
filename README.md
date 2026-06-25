# Servidor Web en Bash

**CLUB ATLÉTICO PLATENSE CAMPEÓN 2025!!**

Servidor HTTP minimalista desarrollado completamente en Bash con fines educativos.

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

**Estructura**

- serverbash.sh     # Script principal
- index.html        # Página principal (Conmemorando al CLUB ATLETICO PLATENSE de Argentina, Campeon 2025)
- access.log        # Logs de conexiones
- tmp/              # Archivos temporales (auto-generados)

**Requisitos**

Instalar socat: sudo apt install socat (Sistemas basados en Debian)

**Uso**

Dar permisos de ejecución: chmod +x serverbash.sh

Ejecutar el servidor: ./serverbash.sh

Abrir en el navegador: http://localhost:8888

**Uso con Docker**

También podés ejecutar el servidor usando Docker, sin necesidad de instalar dependencias manualmente.

Imagen disponible: docker pull christense/serverbash:1.0

Docker Compose

Podés levantar el servidor fácilmente con docker-compose:

services:
  serverbash:
    image: christense/serverbash:1.0
    container_name: serverbash
    ports:
      - "9999:8888"
    volumes:
      - serverbash_data:/opt/ServidorCalamar
    restart: always

volumes:
  serverbash_data:

Ejecutar: docker-compose up -d

Web: http://localhost:9999

**Objetivo Educativo**

Este proyecto está hecho para:

- Entender cómo funcionan los servidores web
- Aprender protocolos HTTP
- Experimentar con Bash scripting avanzado
- Comprender sockets y concurrencia
