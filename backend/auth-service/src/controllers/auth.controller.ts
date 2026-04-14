import { Request, Response } from "express";
import { AuthService } from "../services/auth.service";

export class AuthController {
  static async register(req: Request, res: Response) {
    try {
      const { user, token } = await AuthService.register(req.body);
      res.status(201).json({ user, token });
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }

  static async login(req: Request, res: Response) {
    try {
      const { user, token } = await AuthService.login(req.body);
      res.status(200).json({ user, token });
    } catch (err: any) {
      res.status(401).json({ error: err.message });
    }
  }

  static async forgotPassword(req: Request, res: Response) {
    try {
      const { email } = req.body;
      const result = await AuthService.forgotPassword(email);
      res.status(200).json(result);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }

  static async resetPassword(req: Request, res: Response) {
    try {
      const result = await AuthService.resetPassword(req.body);
      res.status(200).json(result);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }

  static async getUsersBatch(req: Request, res: Response) {
    try {
      const { ids } = req.body;
      const users = await AuthService.getUsersBatch(ids);
      res.status(200).json(users);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }

  static async updateUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const user = await AuthService.updateUser(id, req.body);
      res.status(200).json(user);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }

  static async getUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const user = await AuthService.getUserById(id);
      res.status(200).json(user);
    } catch (err: any) {
      res.status(404).json({ error: err.message });
    }
  }

  static async googleLogin(req: Request, res: Response) {
    try {
      const { idToken, role } = req.body;
      const result = await AuthService.googleLogin(idToken, role);
      res.status(200).json(result);
    } catch (err: any) {
      res.status(401).json({ error: err.message });
    }
  }
}
