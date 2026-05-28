import { Entity, PrimaryColumn, Column, UpdateDateColumn } from "typeorm";

@Entity("user_levels")
export class UserLevel {
  @PrimaryColumn()
  userId!: string;

  @Column()
  levelId!: number;

  @UpdateDateColumn()
  updatedAt!: Date;
}
