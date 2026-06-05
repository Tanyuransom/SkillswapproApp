import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from "typeorm";

@Entity("payments")
export class Payment {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  userId!: string;

  @Column()
  courseId!: string;

  @Column("decimal")
  amount!: number;

  @Column({ nullable: true })
  method?: string;

  @Column("decimal", { default: 0 })
  tax!: number;

  @Column("decimal", { default: 0 })
  total!: number;

  @Column({ nullable: true })
  phoneNumber?: string;

  @Column({ default: "pending" })
  status!: string;

  @CreateDateColumn()
  createdAt!: Date;
}
