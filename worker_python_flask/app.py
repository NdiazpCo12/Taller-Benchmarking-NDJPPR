from flask import Flask, request, jsonify
import psycopg2
import os
import uuid
from datetime import datetime
from decimal import Decimal

app = Flask(__name__)

DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'postgres'),
    'database': os.getenv('DB_NAME', 'orders_db')
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

@app.route('/api/orders', methods=['POST'])
def create_order():
    try:
        data = request.get_json()
        
        if not data or 'customerId' not in data or 'items' not in data:
            return jsonify({'error': 'customerId and items are required'}), 400
        
        if not data['items'] or len(data['items']) == 0:
            return jsonify({'error': 'items cannot be empty'}), 400
        
        total_amount = Decimal('0.00')
        items_count = 0
        
        for item in data['items']:
            if 'productId' not in item or 'quantity' not in item or 'price' not in item:
                return jsonify({'error': 'Each item must have productId, quantity, and price'}), 400
            
            quantity = int(item['quantity'])
            price = Decimal(str(item['price']))
            item_total = price * quantity
            total_amount += item_total
            items_count += quantity
        
        order_id = f"ORD-{uuid.uuid4().hex[:8].upper()}"
        processed_at = datetime.now()
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            cursor.execute(
                """
                INSERT INTO orders (order_id, customer_id, total_amount, items_count, created_at)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (order_id, data['customerId'], total_amount, items_count, processed_at)
            )
            
            for item in data['items']:
                cursor.execute(
                    """
                    INSERT INTO order_items (order_id, product_id, quantity, price)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (order_id, item['productId'], item['quantity'], Decimal(str(item['price'])))
                )
            
            conn.commit()
            
            response = {
                'orderId': order_id,
                'totalAmount': float(total_amount),
                'itemsCount': items_count,
                'processedAt': processed_at.isoformat()
            }
            
            return jsonify(response), 201
            
        except Exception as e:
            conn.rollback()
            return jsonify({'error': str(e)}), 500
        finally:
            cursor.close()
            conn.close()
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002, debug=False)

