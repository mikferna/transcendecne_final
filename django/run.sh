#!/bin/bash
cd /code/django/

# Verificar si los certificados existen
if [ ! -f "$SSL_CERT_FILE" ] || [ ! -f "$SSL_KEY_FILE" ]; then
    echo "ERROR: Certificates not found at $SSL_CERT_FILE or $SSL_KEY_FILE"
    echo "Make sure the frontend/certs directory contains cert.pem and key.pem files."
    exit 1
fi

echo "Using SSL certificates from mounted volume at /code/certs"

pip install --upgrade pip

# Esperar a que PostgreSQL esté listo
echo "Esperando a que PostgreSQL esté disponible..."
until PGPASSWORD=postgres psql -h postgres -U postgres -d elephant -c '\q' 2>/dev/null; do
  echo "PostgreSQL no disponible todavía - esperando..."
  sleep 3
done
echo "PostgreSQL disponible - continuando..."

# Migraciones
python manage.py makemigrations
python manage.py migrate

# Crear superusuario si no existe
python manage.py shell <<EOF
from django.contrib.auth import get_user_model

User = get_user_model()

if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'adminpassword')
EOF

# Recopilar archivos estáticos
python manage.py collectstatic --no-input

# Iniciar servidor con Gunicorn en modo producción
echo "Iniciando servidor Django con HTTPS (Gunicorn en modo producción)..."
gunicorn mysite.wsgi:application \
    --bind=0.0.0.0:8000 \
    --workers=4 \
    --threads=2 \
    --certfile=$SSL_CERT_FILE \
    --keyfile=$SSL_KEY_FILE \
    --access-logfile=- \
    --error-logfile=- \
    --log-level=info