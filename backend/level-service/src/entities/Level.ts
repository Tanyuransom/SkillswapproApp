import { Entity, PrimaryGeneratedColumn, Column } from "typeorm";

@Entity("levels")
export class Level {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  name!: string; // e.g. "Level 1"

  @Column({ nullable: true })
  description?: string;
}
