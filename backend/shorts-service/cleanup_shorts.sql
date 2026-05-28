-- Delete broken records (files missing from disk)
DELETE FROM shorts WHERE "videoUrl" IN (
    '/uploads/shorts/video-1777014243566-302742869.mp4',
    '/uploads/shorts/video-1777015995667-988382240.mp4',
    '/uploads/shorts/video-1777017471312-710106137.mp4',
    '/uploads/shorts/video-1777017481683-104499855.mp4'
);

-- Insert orphan files (exist on disk but not in DB)
INSERT INTO shorts ("tutorId", "tutorName", "courseName", description, "videoUrl", "tutorAvatarUrl", likes, comments)
VALUES 
('8f1ccec7-0e09-4ec5-b64b-f0cc81f86985', 'Tanyu Tanyu', 'SkillProf Tips', 'Recovered Tip 1', '/uploads/shorts/video-1776171529421-323747998.mp4', '', 0, 0),
('8f1ccec7-0e09-4ec5-b64b-f0cc81f86985', 'Tanyu Tanyu', 'SkillProf Tips', 'Recovered Tip 2', '/uploads/shorts/video-1776182193113-447548341.mp4', '', 0, 0),
('8f1ccec7-0e09-4ec5-b64b-f0cc81f86985', 'Tanyu Tanyu', 'SkillProf Tips', 'Recovered Tip 3', '/uploads/shorts/video-1776190729016-709802115.mp4', '', 0, 0),
('8f1ccec7-0e09-4ec5-b64b-f0cc81f86985', 'Tanyu Tanyu', 'SkillProf Tips', 'Recovered Tip 4', '/uploads/shorts/video-1776191299532-359057857.mp4', '', 0, 0),
('8f1ccec7-0e09-4ec5-b64b-f0cc81f86985', 'Tanyu Tanyu', 'SkillProf Tips', 'Recovered Tip 5', '/uploads/shorts/video-1776191401529-60773239.mp4', '', 0, 0),
('8f1ccec7-0e09-4ec5-b64b-f0cc81f86985', 'Tanyu Tanyu', 'SkillProf Tips', 'Recovered Tip 6', '/uploads/shorts/video-1776191935607-246782710.mp4', '', 0, 0),
('8f1ccec7-0e09-4ec5-b64b-f0cc81f86985', 'Tanyu Tanyu', 'SkillProf Tips', 'Recovered Tip 7', '/uploads/shorts/video-1776192352140-769095535.mp4', '', 0, 0),
('8f1ccec7-0e09-4ec5-b64b-f0cc81f86985', 'Tanyu Tanyu', 'SkillProf Tips', 'Recovered Tip 8', '/uploads/shorts/video-1776193777736-788586282.mp4', '', 0, 0);
