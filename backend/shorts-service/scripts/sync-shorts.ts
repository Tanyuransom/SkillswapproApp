import { AppDataSource } from "../src/data-source";
import { Short } from "../src/entities/Short";
import * as fs from "fs";
import * as path from "path";
import { fileURLToPath } from 'url';

// Handling __dirname in ESM if necessary, but ts-node usually handles it
// For safety, let's use a more robust way to get the directory
const currentDir = process.cwd();

async function syncShorts() {
    console.log("🚀 Starting Shorts Synchronization...");
    
    try {
        await AppDataSource.initialize();
        console.log("✅ Database connected.");
    } catch (err) {
        console.error("❌ Database connection failed:", err);
        return;
    }
    
    const shortRepository = AppDataSource.getRepository(Short);
    
    // Use project root relative path
    const uploadDir = path.join(currentDir, "uploads/shorts");
    
    if (!fs.existsSync(uploadDir)) {
        console.error(`❌ Upload directory not found: ${uploadDir}`);
        await AppDataSource.destroy();
        return;
    }
    
    const shortsInDb = await shortRepository.find();
    console.log(`📊 Found ${shortsInDb.length} shorts in database.`);
    
    // 1. Check for broken records (DB record exists but file is missing)
    let brokenCount = 0;
    for (const short of shortsInDb) {
        if (!short.videoUrl) continue;
        
        const fileName = path.basename(short.videoUrl);
        const filePath = path.join(uploadDir, fileName);
        
        if (!fs.existsSync(filePath)) {
            console.warn(`⚠️  Missing file for short ${short.id}: ${fileName}`);
            // Automatically clean up broken records
            console.log(`🧹 Removing broken record: ${short.id}`);
            await shortRepository.remove(short);
            brokenCount++;
        }
    }
    
    // 2. Check for orphan files (File exists but no DB record)
    const filesOnDisk = fs.readdirSync(uploadDir).filter((f: string) => f.endsWith(".mp4"));
    console.log(`📂 Found ${filesOnDisk.length} video files on disk.`);
    
    let orphanCount = 0;
    for (const file of filesOnDisk) {
        const urlInDb = `/uploads/shorts/${file}`;
        const exists = shortsInDb.some((s: any) => s.videoUrl === urlInDb);
        
        if (!exists) {
            console.log(`✨ Found orphan file: ${file}`);
            // Re-import orphan file
            const newShort = shortRepository.create({
                tutorId: "system-sync",
                tutorName: "Recovered Short",
                courseName: "SkillProf Tips",
                description: "Recovered from storage",
                videoUrl: urlInDb,
                tutorAvatarUrl: "",
            } as any);
            await shortRepository.save(newShort);
            orphanCount++;
        }
    }
    
    console.log("\n✅ Sync Complete!");
    console.log(`- Broken records removed: ${brokenCount}`);
    console.log(`- Orphan files re-imported: ${orphanCount}`);
    
    await AppDataSource.destroy();
}

syncShorts().catch(console.error);
