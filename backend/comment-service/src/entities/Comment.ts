import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from "typeorm";

@Entity("comments")
@Index(["targetId", "targetType"])
export class Comment {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  userId!: string;

  @Column()
  userName!: string;

  @Column()
  targetId!: string;

  @Column()
  targetType!: string;

  @Column("text")
  text!: string;

  @CreateDateColumn()
  createdAt!: Date;
}
