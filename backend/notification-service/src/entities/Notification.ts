import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from "typeorm";

@Entity("notifications")
export class Notification {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  userId!: string;

  @Column()
  title!: string;

  @Column()
  message!: string;

  @Column({ default: false })
  isRead!: boolean;

  @Column({ nullable: true })
  type?: string;

  @CreateDateColumn()
  createdAt!: Date;
}
