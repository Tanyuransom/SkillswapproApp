import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from "typeorm";

@Entity("stats")
export class Stat {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  metricName!: string;

  @Column("float")
  value!: number;

  @CreateDateColumn()
  createdAt!: Date;
}
