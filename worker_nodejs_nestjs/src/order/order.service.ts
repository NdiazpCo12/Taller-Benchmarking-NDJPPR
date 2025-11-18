import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { OrderResponseDto } from './dto/order-response.dto';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class OrderService {
  constructor(private readonly databaseService: DatabaseService) {}

  async createOrder(createOrderDto: CreateOrderDto): Promise<OrderResponseDto> {
    let totalAmount = 0;
    let itemsCount = 0;

    for (const item of createOrderDto.items) {
      const itemTotal = item.price * item.quantity;
      totalAmount += itemTotal;
      itemsCount += item.quantity;
    }

    const orderId = `ORD-${uuidv4().substring(0, 8).toUpperCase()}`;
    const processedAt = new Date();

    const client = await this.databaseService.getPool().connect();

    try {
      await client.query('BEGIN');

      await client.query(
        `INSERT INTO orders (order_id, customer_id, total_amount, items_count, created_at)
         VALUES ($1, $2, $3, $4, $5)`,
        [orderId, createOrderDto.customerId, totalAmount, itemsCount, processedAt],
      );

      for (const item of createOrderDto.items) {
        await client.query(
          `INSERT INTO order_items (order_id, product_id, quantity, price)
           VALUES ($1, $2, $3, $4)`,
          [orderId, item.productId, item.quantity, item.price],
        );
      }

      await client.query('COMMIT');

      return {
        orderId,
        totalAmount,
        itemsCount,
        processedAt: processedAt.toISOString(),
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

