set -e

# Datos de conexión al contenedor
CONTAINER="olist_pg"
DB_USER="olist"
DB_NAME="olist"
DATA_DIR="data/raw"

# Función que carga UNA tabla: primero trunca, después copia.
load () {
  local table="$1"      # nombre de la tabla (ej: raw.orders)
  local file="$2"       # nombre del CSV
  local extra="$3"      # opciones extra para el COPY (ej: manejo de BOM)
  echo ">> Cargando $table desde $file ..."
  docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "TRUNCATE $table;"
  docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" \
    -c "\copy $table FROM STDIN WITH (FORMAT csv, HEADER true $extra)" \
    < "$DATA_DIR/$file"
}

# --- Las 9 tablas ---
load "raw.orders"          "olist_orders_dataset.csv"              ""
load "raw.order_items"     "olist_order_items_dataset.csv"         ""
load "raw.order_payments"  "olist_order_payments_dataset.csv"      ""
load "raw.order_reviews"   "olist_order_reviews_dataset.csv"       ""
load "raw.products"        "olist_products_dataset.csv"            ""
load "raw.customers"       "olist_customers_dataset.csv"           ""
load "raw.sellers"         "olist_sellers_dataset.csv"             ""
load "raw.geolocation"     "olist_geolocation_dataset.csv"         ""

load "raw.product_category_translation" "product_category_name_translation.csv" ", ENCODING 'UTF8'"

echo ""
echo "✅ Carga completa."
