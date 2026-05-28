import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from "typeorm";

@Entity("shares")
@Index(["targetId", "targetType"])
export class Share {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  userId!: string;

  @Column()
  targetId!: string;

  @Column()
  targetType!: string;

  @CreateDateColumn()
  createdAt!: Date;
}
