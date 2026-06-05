import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from "typeorm";

@Entity("blog_posts")
export class BlogPost {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  title!: string;

  @Column("text")
  content!: string;

  @Column()
  authorId!: string;

  @Column({ default: "Anonymous" })
  authorName!: string;

  @Column({ nullable: true })
  authorAvatarUrl?: string;

  @Column({ nullable: true })
  imageUrl?: string;

  @Column({ nullable: true })
  category?: string;

  @Column({ nullable: true })
  readTime?: string;

  @CreateDateColumn()
  createdAt!: Date;
}
