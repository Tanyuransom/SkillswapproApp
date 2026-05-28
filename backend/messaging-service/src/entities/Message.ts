import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from "typeorm";

@Entity("messages")
export class Message {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  senderId!: string;

  @Column()
  receiverId!: string;

  @Column("text")
  content!: string;
  
  @Column({ nullable: true })
  senderName?: string;

  @Column({ nullable: true })
  senderAvatarUrl?: string;

  @Column({ nullable: true })
  senderRole?: string;

  @Column({ default: false })
  isRead!: boolean;

  @Column({ type: "timestamp", nullable: true })
  readAt?: Date;

  @CreateDateColumn()
  createdAt!: Date;
}
