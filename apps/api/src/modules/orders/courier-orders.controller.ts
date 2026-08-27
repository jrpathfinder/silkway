import { Controller, Get, Param, Post } from '@nestjs/common';
import { OrdersService } from './orders.service';

/// Без авторизации: у курьера пока нет ни логина, ни собственной сессии
/// (см. apps/customer CourierRepository) — это MVP-разрыв, известный и
/// временный, а не оверсайт. Прежде чем открывать этот путь наружу за
/// пределами доверенного окружения, здесь нужен отдельный механизм
/// аутентификации курьера.
@Controller('courier/orders')
export class CourierOrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Get('offered')
  offered() {
    return { data: this.orders.listByStatuses(['READY_FOR_DELIVERY']) };
  }

  @Post(':id/accept')
  accept(@Param('id') id: string) {
    return { data: this.orders.courierAccept(id) };
  }

  @Post(':id/deny')
  deny() {
    // Назначения конкретных курьеров нет — «отказ» не имеет наблюдаемого
    // эффекта: заказ просто остаётся в общем пуле предложений для всех.
    return { data: { ok: true } };
  }

  @Post(':id/deliver')
  deliver(@Param('id') id: string) {
    return { data: this.orders.markDelivered(id) };
  }
}
