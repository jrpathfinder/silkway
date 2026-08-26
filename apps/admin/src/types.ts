export type Nutrition = {
  caloriesKcal: number;
  proteinG: number;
  fatG: number;
  carbsG: number;
};

export type Category = {
  id: string;
  name: string;
  sortOrder: number;
};

export type Modifier = {
  id: string;
  itemId: string;
  name: string;
  priceRub: number;
};

export type Item = {
  id: string;
  categoryId: string;
  name: string;
  description: string;
  priceRub: number;
  isAvailable: boolean;
  imageUrl?: string;
  weightLabel?: string;
  composition?: string;
  modifierGroupLabel?: string;
  ratingPercent?: number;
  ratingCount?: number;
  nutritionPer100g?: Nutrition;
  modifiers?: Modifier[];
};

export type Promotion = {
  id: string;
  name: string;
  discountType: 'percent' | 'fixed';
  discountValue: number;
  itemId?: string;
  categoryId?: string;
  startsAt?: string;
  endsAt?: string;
  isActive: boolean;
};

export type CatalogExport = {
  categories: Category[];
  items: Item[];
  promotions: Promotion[];
};
