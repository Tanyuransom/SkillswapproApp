import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from "typeorm";
import { Short } from "./Short";

@Entity("short_comments")
export class ShortComment {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  shortId!: string;

  @Column()
  userId!: string;

  @Column()
  userName!: string;

  @Column("text")
  text!: string;

  @CreateDateColumn()
  createdAt!: Date;

  @ManyToOne(() => Short)
  @JoinColumn({ name: "shortId" })
  short!: Short;
}
