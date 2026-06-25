import { db } from "./db";
import { inquiries, type InsertInquiry, type Inquiry } from "@shared/schema";

export interface IStorage {
  createInquiry(inquiry: InsertInquiry): Promise<Inquiry>;
}

export class InMemoryStorage implements IStorage {
  private inquiries: Inquiry[] = [];
  private nextId = 1;

  async createInquiry(inquiry: InsertInquiry): Promise<Inquiry> {
    const newInquiry: Inquiry = {
      id: this.nextId++,
      ...inquiry,
      createdAt: new Date(),
    };
    this.inquiries.push(newInquiry);
    console.log("تم حفظ الاستفسار:", newInquiry);
    return newInquiry;
  }
}

export class DatabaseStorage implements IStorage {
  async createInquiry(inquiry: InsertInquiry): Promise<Inquiry> {
    const [newInquiry] = await db.insert(inquiries).values(inquiry).returning();
    return newInquiry;
  }
}

export const storage = db ? new DatabaseStorage() : new InMemoryStorage();
